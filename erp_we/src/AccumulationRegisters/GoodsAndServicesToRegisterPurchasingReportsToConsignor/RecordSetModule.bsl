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
	
	LockForUpdate = True;
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.VATRate AS VATRate,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.Count
	|		ELSE -Table.Count
	|	END AS CountBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.VATAmount
	|		ELSE -Table.VATAmount
	|	END AS VATAmountBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.AmountIncludingVAT
	|		ELSE -Table.AmountIncludingVAT
	|	END AS AmountIncludingVATBeforeWrite
	|INTO MovementOfGoodsInWarehousesBeforeRecording
	|FROM
	|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (NOT &IsNew)";
	Query.Execute();

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

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.Period AS Period,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Purpose AS Purpose,
	|	ChangesTable.CCDNumber AS CCDNumber,
	|	ChangesTable.VATRate AS VATRate,
	|	SUM(ChangesTable.Count) AS Count,
	|	SUM(ChangesTable.VATAmount) AS VATAmount,
	|	SUM(ChangesTable.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		Table.Organization AS Organization,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Purpose AS Purpose,
	|		Table.CCDNumber AS CCDNumber,
	|		Table.VATRate AS VATRate,
	|		Table.CountBeforeWrite AS Count,
	|		Table.VATAmountBeforeWrite AS VATAmount,
	|		Table.AmountIncludingVATBeforeWrite AS AmountIncludingVAT
	|	FROM
	|		MovementOfGoodsInWarehousesBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period,
	|		Table.Organization ,
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.CCDNumber AS CCDNumber,
	|		Table.VATRate AS VATRate,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.Count
	|			ELSE Table.Count
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.VATAmount
	|			ELSE Table.VATAmount
	|		END,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.AmountIncludingVAT
	|			ELSE Table.AmountIncludingVAT
	|		END
	|	FROM
	|		AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Period, 
	|	ChangesTable.Organization,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.CCDNumber,
	|	ChangesTable.VATRate
	|
	|HAVING
	|	SUM(ChangesTable.Count) <> 0
	|	OR SUM(ChangesTable.VATAmount) <> 0
	|	OR SUM(ChangesTable.AmountIncludingVAT) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP MovementOfGoodsInWarehousesBeforeRecording";
	
	QueryResultsArray = Query.ExecuteBatch(); 
	
	Selection = QueryResultsArray[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"PreparationOfGoodsAndServicesForPreparationOfReportsToPurchasingCommittee", HasChanges);
	
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
		|	InitialEntries.Purpose AS Purpose,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.AmountIncludingVAT AS AmountIncludingVAT,
		|	InitialEntries.SumMan AS SumMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS InitialEntries
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
		|		InitialEntries.Purpose AS Purpose,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.AmountIncludingVAT AS AmountIncludingVAT,
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
		|		Records.Currency AS Currency,
		|		Records.Organization AS Organization,
		|		Records.Purpose AS Purpose,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.AmountIncludingVAT AS AmountIncludingVAT,
		|		-Records.SumMan AS SumMan

		|	FROM
		|		AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Currency,
		|	Table.Organization,
		|	Table.Purpose,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.AmountIncludingVAT) <> 0 OR SUM(Table.SumMan) <> 0
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
