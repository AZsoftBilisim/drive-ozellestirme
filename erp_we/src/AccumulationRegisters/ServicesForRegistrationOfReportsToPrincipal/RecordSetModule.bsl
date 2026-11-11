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
	
	// The current state of the set is placed in the temporary table "
	// Service Movement and Report formationprincipalperrecording" in order to get a change in the new set relative to the current one when recording.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Period						AS Period,
	|	Table.Organization					AS Organization,
	|	Table.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Table.Terms  				AS Terms,
	|	Table.Currency   					AS Currency,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Count
	|		ELSE
	|			-Table.Count
	|	END                  AS CountBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.RevenueAmount
	|		ELSE
	|			-Table.RevenueAmount
	|	END                  AS RevenueAmountBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.VATAmount
	|		ELSE
	|			-Table.VATAmount
	|	END                  AS VATAmountBeforeWrite
	|INTO PreparingServicesForReportingToPrincipalBeforeRecording
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS Table
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
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Period,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ChangesTable.Terms AS Terms,
	|	ChangesTable.Currency AS Currency,
	|	SUM(ChangesTable.Count) AS CountUpdate,
	|	SUM(ChangesTable.RevenueAmount) AS RevenueAmountUpdate,
	|	SUM(ChangesTable.VATAmount) AS VATAmountUpdate
	|INTO RequirementsOfServiceForPreparationOfReportsToPrincipalChange
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		Table.Organization AS Organization,
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.Terms AS Terms,
	|		Table.Currency AS Currency,
	|		Table.CountBeforeWrite AS Count,
	|		Table.RevenueAmountBeforeWrite AS RevenueAmount,
	|		Table.VATAmountBeforeWrite AS VATAmount
	|	FROM
	|		PreparingServicesForReportingToPrincipalBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period,
	|		Table.Organization,
	|		Table.ItemsLocationAttributes,
	|		Table.Terms,
	|		Table.Currency,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.Count
	|			ELSE Table.Count
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.RevenueAmount
	|			ELSE Table.RevenueAmount
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.VATAmount
	|			ELSE Table.VATAmount
	|		END
	|	FROM
	|		AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH),
	|	ChangesTable.Organization,
	|	ChangesTable.ItemsLocationAttributes,
	|	ChangesTable.Terms,
	|	ChangesTable.Currency
	|
	|HAVING
	|	(SUM(ChangesTable.Count) <> 0
	|		OR SUM(ChangesTable.RevenueAmount) <> 0
	|		OR SUM(ChangesTable.VATAmount) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PreparingServicesForReportingToPrincipalBeforeRecording";
	
	Selection = Query.ExecuteBatch()[0].Select();
		
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RequirementsOfServiceForPreparationOfReportsToPrincipalChange", Selection.Next() And Selection.Count > 0);
	
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
		|	InitialEntries.Currency AS Currency,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Terms AS Terms,
		|	InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.RevenueAmount AS RevenueAmount,
		|	InitialEntries.RevenueAmountMan AS RevenueAmountMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS InitialEntries
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
		|		InitialEntries.Currency AS Currency,
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Terms AS Terms,
		|		InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.RevenueAmount AS RevenueAmount,
		|		InitialEntries.RevenueAmountMan AS RevenueAmountMan
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
		|		Records.Currency AS Currency,
		|		Records.Organization AS Organization,
		|		Records.Terms AS Terms,
		|		Records.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.RevenueAmount AS RevenueAmount,
		|		-Records.RevenueAmountMan AS RevenueAmountMan
		|	FROM
		|		AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Currency,
		|	Table.Organization,
		|	Table.Terms,
		|	Table.ItemsLocationAttributes,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.RevenueAmount) <> 0 OR SUM(Table.RevenueAmountMan) <> 0
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
