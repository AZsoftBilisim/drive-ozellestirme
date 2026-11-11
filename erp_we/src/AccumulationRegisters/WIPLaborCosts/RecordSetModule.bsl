#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Costs.Period,
	|	Costs.Recorder,
	|	Costs.Organization,
	|	Costs.Department,
	|	Costs.ProductionOrder,
	|	Costs.RowCodeProducts,
	|	Costs.Stage,
	|	Costs.ProductCostElement,
	|	Costs.WorkKind,
	|	Costs.ProductsGroup,
	|
	|	Costs.Count,
	|	Costs.StandardCost,
	|	Costs.Cost,
	|	Costs.LocalCost,
	|	Costs.CostOfPersonalIncomeTax
	|INTO WIPLaborCostsBeforeWrite
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS Costs
	|WHERE
	|	Costs.Recorder = &Recorder
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	Query = New Query("SELECT
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	Table.ProductionOrder AS ProductionOrder,
	|	Table.RowCodeProducts AS RowCodeProducts,
	|	Table.Stage AS Stage,
	|	Table.ProductCostElement AS ProductCostElement,
	|	Table.WorkKind AS WorkKind,
	|	Table.ProductsGroup AS ProductsGroup,
	|	SUM(Table.Count) AS CountUpdate,
	|	SUM(Table.StandardCost) AS StandardCostUpdate,
	|	SUM(Table.Cost) AS CostUpdate,
	|	SUM(Table.LocalCost) AS LocalCostUpdate,
	|	SUM(Table.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTaxUpdate
	|INTO ChangesTableWIPLaborCosts
	|FROM
	|	(SELECT
	|		Costs.Period,
	|		Costs.Recorder,
	|		Costs.Organization,
	|		Costs.Department,
	|		Costs.ProductionOrder,
	|		Costs.RowCodeProducts,
	|		Costs.Stage,
	|		Costs.ProductCostElement,
	|		Costs.WorkKind,
	|		Costs.ProductsGroup,
	|		Costs.Count,
	|		Costs.StandardCost,
	|		Costs.Cost,
	|		Costs.LocalCost,
	|		Costs.CostOfPersonalIncomeTax
	|	FROM
	|		WIPLaborCostsBeforeWrite AS Costs
	|
	|	UNION ALL
	|
	|	SELECT
	|		Costs.Period,
	|		Costs.Recorder,
	|		Costs.Organization,
	|		Costs.Department,
	|		Costs.ProductionOrder,
	|		Costs.RowCodeProducts,
	|		Costs.Stage,
	|		Costs.ProductCostElement,
	|		Costs.WorkKind,
	|		Costs.ProductsGroup,
	|		-Costs.Count,
	|		-Costs.StandardCost,
	|		-Costs.Cost,
	|		-Costs.LocalCost,
	|		-Costs.CostOfPersonalIncomeTax
	|	FROM
	|		AccumulationRegister.WIPLaborCosts AS Costs
	|	WHERE
	|		Costs.Recorder = &Recorder) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Organization,
	|	Table.Department,
	|	Table.ProductionOrder,
	|	Table.RowCodeProducts,
	|	Table.Stage,
	|	Table.ProductCostElement,
	|	Table.WorkKind,
	|	Table.ProductsGroup
	|HAVING
	|	SUM(Table.Count) <> 0
	|	OR SUM(Table.StandardCost) <> 0
	|	OR SUM(Table.Cost) <> 0
	|	OR SUM(Table.LocalCost) <> 0
	|	OR SUM(Table.CostOfPersonalIncomeTax) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP WIPLaborCostsBeforeWrite");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
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
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Department AS Department,
		|	InitialEntries.ProductionOrder AS ProductionOrder,
		|	InitialEntries.ProductionLot AS ProductionLot,
		|	InitialEntries.LotCalculation AS LotCalculation,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.Cost AS Cost
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.WIPLaborCosts AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
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
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Department AS Department,
		|		InitialEntries.ProductionOrder AS ProductionOrder,
		|		InitialEntries.ProductionLot AS ProductionLot,
		|		InitialEntries.LotCalculation AS LotCalculation,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.Cost AS Cost
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
		|		Records.Organization AS Organization,
		|		Records.Department AS Department,
		|		Records.ProductionOrder AS ProductionOrder,
		|		Records.ProductionLot AS ProductionLot,
		|		Records.LotCalculation AS LotCalculation,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.Cost AS Cost
		|	FROM
		|		AccumulationRegister.WIPLaborCosts AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.Department,
		|	Table.ProductionOrder,
		|	Table.ProductionLot,
		|	Table.LotCalculation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Cost) <> 0
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
