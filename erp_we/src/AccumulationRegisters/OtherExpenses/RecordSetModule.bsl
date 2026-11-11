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
	SourceKind = New Array;
	If Not ClosingExpensesFromDisposalOfFixedAssets.RegisteredRecordsAreRecordedWhenOperationIsPerformed(ThisObject)
		And AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		SourceKind.Add(Enums.MovementSourcesKinds.ClosingExpensesFromDisposalOfFixedAssets);
	EndIf;
	ExcludeBTSettings = New Array;
	ExcludeBTSettings.Add(Catalogs.BusinessTransactionsSettings.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer);
	DocumentsPosting.SaveRegisteredRecordsGeneratedOnDeferredBasis(ThisObject, Replacing, SourceKind, ExcludeBTSettings);
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The current state of the balances is placed in a temporary table
	// in order to get a change in the current register balances when writing.
	
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
		|	ChangesTable.Department,
		|	ChangesTable.ExpenseItem,
		|	ChangesTable.DimensionOfExpenses,
		|	ChangesTable.LineOfBusiness,
		|	ChangesTable.VariancePeriod,
		|	SUM(ChangesTable.Sum) AS SumUpdate,
		|	SUM(ChangesTable.AmountExcludingVAT) AS AmountExcludingVATUpdate,
		|	SUM(ChangesTable.SumCompl) AS SumComplUpdate,
		|	SUM(ChangesTable.PermanentDifference) AS PermanentDifferenceUpdate,
		|	SUM(ChangesTable.CostTD) AS CostTDUpdate,
		|	SUM(ChangesTable.AITAmount) AS AITAmountUpdate,
		|	SUM(ChangesTable.SumMan) AS SumManUpdate
		|
		|INTO RegisteredRecordsOtherExpensesUpdate
		|
		|FROM
		|	ChangesTableOtherExpenses AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.Department,
		|	ChangesTable.ExpenseItem,
		|	ChangesTable.Organization,
		|	ChangesTable.DimensionOfExpenses,
		|	ChangesTable.LineOfBusiness,
		|	ChangesTable.VariancePeriod
		|
		|HAVING
		|	SUM(ChangesTable.Sum) <> 0
		|	OR SUM(ChangesTable.AmountExcludingVAT) <> 0
		|	OR SUM(ChangesTable.SumCompl) <> 0
		|	OR SUM(ChangesTable.PermanentDifference) <> 0
		|	OR SUM(ChangesTable.CostTD) <> 0
		|	OR SUM(ChangesTable.AITAmount) <> 0 
		|	OR SUM(ChangesTable.SumMan) <> 0
		|
		|INDEX BY
		|	DimensionOfExpenses";
	
		Selection = Query.Execute().Select();
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"RegisteredRecordsOtherExpensesUpdate", Selection.Next() And Selection.Count > 0);
		
	EndIf;
	CostsServer.CheckOnRecordingOtherExpenses(Filter.Recorder.Value, Cancel);
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
		|	InitialEntries.LineOfBusiness AS LineOfBusiness,
		|	InitialEntries.BusinessOperation AS BusinessOperation,
		|	InitialEntries.ExpenseItem AS ExpenseItem,
		|	InitialEntries.DimensionOfExpenses AS DimensionOfExpenses,
		|	InitialEntries.CalculationOfCost AS CalculationOfCost,
		|	InitialEntries.LotCalculation AS LotCalculation,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.SumMan AS SumMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.OtherExpenses AS InitialEntries
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
		|		InitialEntries.LineOfBusiness AS LineOfBusiness,
		|		InitialEntries.BusinessOperation AS BusinessOperation,
		|		InitialEntries.ExpenseItem AS ExpenseItem,
		|		InitialEntries.DimensionOfExpenses AS DimensionOfExpenses,
		|		InitialEntries.CalculationOfCost AS CalculationOfCost,
		|		InitialEntries.LotCalculation AS LotCalculation,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.Sum AS Sum,
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
		|		Records.Organization AS Organization,
		|		Records.Department AS Department,
		|		Records.LineOfBusiness AS LineOfBusiness,
		|		Records.BusinessOperation AS BusinessOperation,
		|		Records.ExpenseItem AS ExpenseItem,
		|		Records.DimensionOfExpenses AS DimensionOfExpenses,
		|		Records.CalculationOfCost AS CalculationOfCost,
		|		Records.LotCalculation AS LotCalculation,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.Sum AS Sum,
		|		-Records.SumMan AS SumMan
		|	FROM
		|		AccumulationRegister.OtherExpenses AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.Department,
		|	Table.LineOfBusiness,
		|	Table.BusinessOperation,
		|	Table.ExpenseItem,
		|	Table.DimensionOfExpenses,
		|	Table.CalculationOfCost,
		|	Table.LotCalculation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0 OR SUM(Table.SumMan) <> 0
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
