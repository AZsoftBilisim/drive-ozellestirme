
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
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Organization AS Organization,
	|	Table.FixedAsset AS FixedAsset,
	|	Table.Department AS Department,
	|	Table.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.Depreciation AS Depreciation,
	|	Table.DepreciationLocal AS DepreciationLocal,
	|	Table.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|	Table.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|	Table.DepreciationTD AS DepreciationTD,
	|	Table.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|	Table.DepreciationTaxAccountingTargetFinancing AS DepreciationTaxAccountingTargetFinancing,
	|	Table.DepreciationTargetFinancingPD AS DepreciationTargetFinancingPD,
	|	Table.DepreciationOfTargetFinancingTD AS DepreciationOfTargetFinancingTD,
	|	Table.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	Table.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal
	|INTO FixedAssetsDepreciationChargeBeforeWrite
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (Table.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|		OR Table.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|		OR Table.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|		OR Table.Recorder REFS Document.FixedAssetsDepreciationCharge2_4)";
	
	Query.Execute();
	
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
	
	QueryText =
	"SELECT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Period,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.FixedAsset AS FixedAsset,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	&Recorder AS Document
	|INTO FixedAssetsDepreciationChargeUpdate
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		Table.RecordType AS RecordType,
	|		Table.Organization AS Organization,
	|		Table.FixedAsset AS FixedAsset,
	|		Table.Department AS Department,
	|		Table.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		Table.LineOfBusiness AS LineOfBusiness,
	|		Table.Depreciation AS Depreciation,
	|		Table.DepreciationLocal AS DepreciationLocal,
	|		Table.DepreciationInTaxAccounting AS DepreciationInTaxAccounting,
	|		Table.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|		Table.DepreciationTD AS DepreciationTD,
	|		Table.FixedAssetDepreciationTargetFinancing AS FixedAssetDepreciationTargetFinancing,
	|		Table.DepreciationTaxAccountingTargetFinancing AS DepreciationTaxAccountingTargetFinancing,
	|		Table.DepreciationTargetFinancingPD AS DepreciationTargetFinancingPD,
	|		Table.DepreciationOfTargetFinancingTD AS DepreciationOfTargetFinancingTD,
	|		Table.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|		Table.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|		AND (Table.Recorder REFS Document.EntryOfCapitalAssetsBalance2_4
	|			OR Table.Recorder REFS Document.OBEntrySubAssetsAndComponentsOfDepreciation
	|			OR Table.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|			OR Table.Recorder REFS Document.FixedAssetsDepreciationCharge2_4)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period,
	|		Table.RecordType,
	|		Table.Organization,
	|		Table.FixedAsset,
	|		Table.Department,
	|		Table.FinancialAccountingGroup,
	|		Table.LineOfBusiness,
	|		-Table.Depreciation,
	|		-Table.DepreciationLocal,
	|		-Table.DepreciationInTaxAccounting,
	|		-Table.DepreciationPermanentDifferences,
	|		-Table.DepreciationTD,
	|		-Table.FixedAssetDepreciationTargetFinancing,
	|		-Table.DepreciationTaxAccountingTargetFinancing,
	|		-Table.DepreciationTargetFinancingPD,
	|		-Table.DepreciationOfTargetFinancingTD,
	|		-Table.DepreciationRevaluationReserve,
	|		-Table.DepreciationRevaluationReserveLocal
	|	FROM
	|		FixedAssetsDepreciationChargeBeforeWrite AS Table) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Period,
	|	ChangesTable.RecordType,
	|	ChangesTable.Organization,
	|	ChangesTable.FixedAsset,
	|	ChangesTable.Department,
	|	ChangesTable.FinancialAccountingGroup,
	|	ChangesTable.LineOfBusiness
	|
	|HAVING
	|	(SUM(ChangesTable.Depreciation) <> 0
	|		OR SUM(ChangesTable.DepreciationLocal) <> 0
	|		OR SUM(ChangesTable.DepreciationInTaxAccounting) <> 0
	|		OR SUM(ChangesTable.DepreciationPermanentDifferences) <> 0
	|		OR SUM(ChangesTable.DepreciationTD) <> 0
	|		OR SUM(ChangesTable.FixedAssetDepreciationTargetFinancing) <> 0
	|		OR SUM(ChangesTable.DepreciationTaxAccountingTargetFinancing) <> 0
	|		OR SUM(ChangesTable.DepreciationTargetFinancingPD) <> 0
	|		OR SUM(ChangesTable.DepreciationOfTargetFinancingTD) <> 0
	|		OR SUM(ChangesTable.DepreciationRevaluationReserve) <> 0
	|		OR SUM(ChangesTable.DepreciationRevaluationReserveLocal) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FixedAssetsDepreciationChargeBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"FixedAssetsDepreciationChargeUpdate", Selection.Next() And Selection.Count > 0);
	
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
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Department AS Department,
		|	InitialEntries.LineOfBusiness AS LineOfBusiness,
		|	InitialEntries.FixedAsset AS FixedAsset,
		|	InitialEntries.Depreciation AS Depreciation
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.FixedAssetsDepreciationCharge AS InitialEntries
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
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Department AS Department,
		|		InitialEntries.LineOfBusiness AS LineOfBusiness,
		|		InitialEntries.FixedAsset AS FixedAsset,
		|		InitialEntries.Depreciation AS Depreciation
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
		|		Records.FixedAsset AS FixedAsset,
		|		-Records.Depreciation AS Depreciation
		|	FROM
		|		AccumulationRegister.FixedAssetsDepreciationCharge AS Records
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
		|	Table.FixedAsset
		|HAVING
		|	SUM(Table.Depreciation) <> 0
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