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
	
	AdditionalProperties.Insert("SampleTextOfChangeTable", QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
	
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
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
	
		Query.Text =
		"SELECT
		|	MIN(ChangesTable.Recorder) AS Recorder,
		|	MIN(BEGINOFPERIOD(ChangesTable.Period, MONTH)) AS BegOfMonth,
		|	ChangesTable.Organization,
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.InventoryOwnerAttribute,
		|	ChangesTable.LineOfBusiness,
		|	ChangesTable.Department,
		|	ChangesTable.StorageLocation,
		|	ChangesTable.VariancePeriod,
		|	SUM(ChangesTable.CostVariancesIncludingVAT) AS CostVariancesIncludingVATUpdate,
		|	SUM(ChangesTable.CostVariancesExcludingVAT) AS CostVariancesExcludingVATUpdate,
		|	SUM(ChangesTable.CostVariancesLocal) AS CostVariancesLocalUpdate,
		|	SUM(ChangesTable.CostVariancesMgmt) AS CostVariancesMgmtUpdate,
		|	SUM(ChangesTable.AdditionalExpensesIncludingVAT) AS AdditionalExpensesIncludingVATUpdate,
		|	SUM(ChangesTable.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVATUpdate,
		|	SUM(ChangesTable.AddExpensesLocal) AS AddExpensesLocalUpdate,
		|	SUM(ChangesTable.AddExpensesMan) AS AddExpensesManUpdate,
		|	SUM(ChangesTable.VATLocal) AS VATLocalUpdate,
		|	SUM(ChangesTable.VATManag) AS VATManagUpdate,
		|	SUM(ChangesTable.PermanentDifference) AS PermanentDifferenceUpdate,
		|	SUM(ChangesTable.CostTD) AS CostTDUpdate,
		|	SUM(ChangesTable.AIT) AS AITUpdate
		|
		|INTO RegisteredRecordedDeviationsInCostOfGoodsChange
		|
		|FROM
		|	ChangesTableGoodsCostVariances AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.Organization,
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.InventoryOwnerAttribute,
		|	ChangesTable.LineOfBusiness,
		|	ChangesTable.Department,
		|	ChangesTable.StorageLocation,
		|	ChangesTable.VariancePeriod
		|
		|HAVING
		|	SUM(ChangesTable.CostVariancesIncludingVAT) <> 0
		|	OR SUM(ChangesTable.CostVariancesExcludingVAT) <> 0
		|	OR SUM(ChangesTable.CostVariancesLocal) <> 0
		|	OR SUM(ChangesTable.CostVariancesMgmt) <> 0
		|	OR SUM(ChangesTable.AdditionalExpensesIncludingVAT) <> 0
		|	OR SUM(ChangesTable.AdditionalExpensesExcludingVAT) <> 0
		|	OR SUM(ChangesTable.AddExpensesLocal) <> 0
		|	OR SUM(ChangesTable.AddExpensesMan) <> 0
		|	OR SUM(ChangesTable.VATLocal) <> 0
		|	OR SUM(ChangesTable.VATManag) <> 0
		|	OR SUM(ChangesTable.PermanentDifference) <> 0
		|	OR SUM(ChangesTable.CostTD) <> 0
		|	OR SUM(ChangesTable.AIT) <> 0
		|
		|INDEX BY
		|	Products";
	
		Selection = Query.Execute().Select();
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"RegisteredRecordedDeviationsInCostOfGoodsChange", Selection.Next() And Selection.Count > 0);
		
	EndIf;
	
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
		|	InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	InitialEntries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	InitialEntries.LineOfBusiness AS LineOfBusiness,
		|	InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|	InitialEntries.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|	InitialEntries.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|	InitialEntries.CalculationOfCost AS CalculationOfCost,
		|	InitialEntries.LotCalculation AS LotCalculation,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.GoodsCostVariances AS InitialEntries
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
		|		InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		InitialEntries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|		InitialEntries.LineOfBusiness AS LineOfBusiness,
		|		InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|		InitialEntries.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		InitialEntries.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		InitialEntries.CalculationOfCost AS CalculationOfCost,
		|		InitialEntries.LotCalculation AS LotCalculation,
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
		|		Records.Organization AS Organization,
		|		Records.Department AS Department,
		|		Records.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Records.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|		Records.LineOfBusiness AS LineOfBusiness,
		|		Records.CorLineOfBusiness AS CorLineOfBusiness,
		|		-Records.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		-Records.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		Records.CalculationOfCost AS CalculationOfCost,
		|		Records.LotCalculation AS LotCalculation,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.GoodsCostVariances AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.Department,
		|	Table.InventoryOwnerAttribute,
		|	Table.CorInventoryOwnerAttribute,
		|	Table.LineOfBusiness,
		|	Table.CorLineOfBusiness,
		|	Table.CalculationOfCost,
		|	Table.LotCalculation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.CostVariancesIncludingVAT) <> 0 OR SUM(Table.AdditionalExpensesIncludingVAT) <> 0
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
