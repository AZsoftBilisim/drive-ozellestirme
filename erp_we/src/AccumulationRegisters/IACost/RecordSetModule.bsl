#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	PrepareDataForGeneratingTasksWhenRecording();
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Active AS Active,
	|	TableBeforeWrite.Period AS Period,
	|	TableBeforeWrite.Organization AS Organization,
	|	TableBeforeWrite.Department AS Department,
	|	TableBeforeWrite.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|	TableBeforeWrite.IntangibleAsset AS IntangibleAsset,
	|	TableBeforeWrite.Cost AS Cost,
	|	TableBeforeWrite.LocalCost AS LocalCost,
	|	TableBeforeWrite.CostInTaxAccounting AS CostInTaxAccounting,
	|	TableBeforeWrite.CostPermanentDifference AS CostPermanentDifference,
	|	TableBeforeWrite.CostTemporaryDifference AS CostTemporaryDifference,
	|	TableBeforeWrite.CostTargetFinancing AS CostTargetFinancing,
	|	TableBeforeWrite.CostTargetFinancingTA AS CostTargetFinancingTA,
	|	TableBeforeWrite.CostTargetFinancingPD AS CostTargetFinancingPD,
	|	TableBeforeWrite.CostTargetFinancingTD AS CostTargetFinancingTD,
	|	TableBeforeWrite.TAExpenseAmountOfInvestmentTaxDeduction AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	TableBeforeWrite.CostRevaluationReserve AS CostRevaluationReserve,
	|	TableBeforeWrite.CostRevaluationReserveLocal AS CostRevaluationReserveLocal,
	|	TableBeforeWrite.CostGainMA AS CostGainMA,
	|	TableBeforeWrite.CostGainLocal AS CostGainLocal,
	|	TableBeforeWrite.PreliminaryCostMan AS PreliminaryCostMan,
	|	TableBeforeWrite.PreliminaryCostLocal AS PreliminaryCostLocal,
	|	TableBeforeWrite.BusinessOperation AS BusinessOperation,
	|	TableBeforeWrite.RecordType AS RecordType,
	|	TableBeforeWrite.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	TableBeforeWrite.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TableBeforeWrite.RecordInManAccounting AS RecordInManAccounting
	|
	|INTO IACostBeforeWrite
	|
	|FROM
	|	AccumulationRegister.IACost AS TableBeforeWrite
	|
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure PrepareDataForGeneratingTasksWhenRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	TableOfDifferences.Period AS Period,
	|	TableOfDifferences.Organization AS Organization,
	|	TableOfDifferences.IntangibleAsset AS IntangibleAsset,
	|	MAX(TableOfDifferences.RecordInLocalAccounting) AS RecordInLocalAccounting,
	|	MAX(TableOfDifferences.RecordInManAccounting) AS RecordInManAccounting,
	|	&Recorder AS Document
	|
	|INTO IACostUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Active AS Active,
	|		TableBeforeWrite.Period AS Period,
	|		TableBeforeWrite.Organization AS Organization,
	|		TableBeforeWrite.IntangibleAsset AS IntangibleAsset,
	|		TableBeforeWrite.Department AS Department,
	|		TableBeforeWrite.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.Cost
	|			ELSE - TableBeforeWrite.Cost
	|		END AS Cost,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.LocalCost 
	|			ELSE - TableBeforeWrite.LocalCost 
	|		END AS LocalCost,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostInTaxAccounting
	|			ELSE - TableBeforeWrite.CostInTaxAccounting
	|		END AS CostInTaxAccounting,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostPermanentDifference
	|			ELSE - TableBeforeWrite.CostPermanentDifference
	|		END AS CostPermanentDifference,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostTemporaryDifference
	|			ELSE - TableBeforeWrite.CostTemporaryDifference
	|		END AS CostTemporaryDifference,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostTargetFinancing
	|			ELSE - TableBeforeWrite.CostTargetFinancing
	|		END AS CostTargetFinancing,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostTargetFinancingTA
	|			ELSE - TableBeforeWrite.CostTargetFinancingTA
	|		END AS CostTargetFinancingTA,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostTargetFinancingPD
	|			ELSE - TableBeforeWrite.CostTargetFinancingPD
	|		END AS CostTargetFinancingPD,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostTargetFinancingTD
	|			ELSE - TableBeforeWrite.CostTargetFinancingTD
	|		END AS CostTargetFinancingTD,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.TAExpenseAmountOfInvestmentTaxDeduction
	|			ELSE - TableBeforeWrite.TAExpenseAmountOfInvestmentTaxDeduction
	|		END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostRevaluationReserve
	|			ELSE - TableBeforeWrite.CostRevaluationReserve
	|		END AS CostRevaluationReserve,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostRevaluationReserveLocal
	|			ELSE - TableBeforeWrite.CostRevaluationReserveLocal
	|		END AS CostRevaluationReserveLocal,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostGainMA
	|			ELSE - TableBeforeWrite.CostGainMA
	|		END AS CostGainMA,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.CostGainLocal
	|			ELSE - TableBeforeWrite.CostGainLocal
	|		END AS CostGainLocal,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.PreliminaryCostMan
	|			ELSE - TableBeforeWrite.PreliminaryCostMan
	|		END AS PreliminaryCostMan,
	|
	|		CASE
	|			WHEN TableBeforeWrite.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN TableBeforeWrite.PreliminaryCostLocal
	|			ELSE - TableBeforeWrite.PreliminaryCostLocal
	|		END AS PreliminaryCostLocal,
	|
	|		TableBeforeWrite.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|		TableBeforeWrite.RecordInManAccounting   AS RecordInManAccounting
	|	FROM
	|		IACostBeforeWrite AS TableBeforeWrite
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableWhenWriting.Active AS Active,
	|		TableWhenWriting.Period AS Period,
	|		TableWhenWriting.Organization AS Organization,
	|		TableWhenWriting.IntangibleAsset AS IntangibleAsset,
	|		TableWhenWriting.Department AS Department,
	|		TableWhenWriting.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		TableWhenWriting.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.Cost
	|			ELSE TableWhenWriting.Cost
	|		END AS Cost,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.LocalCost 
	|			ELSE TableWhenWriting.LocalCost 
	|		END AS LocalCost,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostInTaxAccounting
	|			ELSE TableWhenWriting.CostInTaxAccounting
	|		END AS CostInTaxAccounting,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostPermanentDifference
	|			ELSE TableWhenWriting.CostPermanentDifference
	|		END AS CostPermanentDifference,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostTemporaryDifference
	|			ELSE TableWhenWriting.CostTemporaryDifference
	|		END AS CostTemporaryDifference,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostTargetFinancing
	|			ELSE TableWhenWriting.CostTargetFinancing
	|		END AS CostTargetFinancing,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostTargetFinancingTA
	|			ELSE TableWhenWriting.CostTargetFinancingTA
	|		END AS CostTargetFinancingTA,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostTargetFinancingPD
	|			ELSE TableWhenWriting.CostTargetFinancingPD
	|		END AS CostTargetFinancingPD,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostTargetFinancingTD
	|			ELSE TableWhenWriting.CostTargetFinancingTD
	|		END AS CostTargetFinancingTD,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.TAExpenseAmountOfInvestmentTaxDeduction
	|			ELSE TableWhenWriting.TAExpenseAmountOfInvestmentTaxDeduction
	|		END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostRevaluationReserve
	|			ELSE TableWhenWriting.CostRevaluationReserve
	|		END AS CostRevaluationReserve,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostRevaluationReserveLocal
	|			ELSE TableWhenWriting.CostRevaluationReserveLocal
	|		END AS CostRevaluationReserveLocal,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostGainMA
	|			ELSE TableWhenWriting.CostGainMA
	|		END AS CostGainMA,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.CostGainLocal
	|			ELSE TableWhenWriting.CostGainLocal
	|		END AS CostGainLocal,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.PreliminaryCostMan
	|			ELSE TableWhenWriting.PreliminaryCostMan
	|		END AS PreliminaryCostMan,
	|
	|		CASE
	|			WHEN TableWhenWriting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TableWhenWriting.PreliminaryCostLocal
	|			ELSE TableWhenWriting.PreliminaryCostLocal
	|		END AS PreliminaryCostLocal,
	|
	|		TableWhenWriting.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|		TableWhenWriting.RecordInManAccounting   AS RecordInManAccounting
	|	FROM
	|		AccumulationRegister.IACost AS TableWhenWriting
	|	WHERE
	|		TableWhenWriting.Recorder = &Recorder
	|
	|	) AS TableOfDifferences
	|
	|GROUP BY
	|	TableOfDifferences.Active,
	|	TableOfDifferences.Period,
	|	TableOfDifferences.Organization,
	|	TableOfDifferences.IntangibleAsset,
	|	TableOfDifferences.Department,
	|	TableOfDifferences.FinancialAccountingGroup,
	|	TableOfDifferences.LineOfBusiness
	|
	|HAVING
	|	(SUM(TableOfDifferences.Cost) <> 0
	|		OR SUM(TableOfDifferences.LocalCost) <> 0
	|		OR SUM(TableOfDifferences.CostInTaxAccounting) <> 0
	|		OR SUM(TableOfDifferences.CostPermanentDifference) <> 0
	|		OR SUM(TableOfDifferences.CostTemporaryDifference) <> 0
	|		OR SUM(TableOfDifferences.CostTargetFinancing) <> 0
	|		OR SUM(TableOfDifferences.CostTargetFinancingTA) <> 0
	|		OR SUM(TableOfDifferences.CostTargetFinancingPD) <> 0
	|		OR SUM(TableOfDifferences.CostTargetFinancingTD) <> 0
	|		OR SUM(TableOfDifferences.TAExpenseAmountOfInvestmentTaxDeduction) <> 0
	|		OR SUM(TableOfDifferences.PreliminaryCostMan) <> 0
	|		OR SUM(TableOfDifferences.PreliminaryCostLocal) <> 0
	|		OR SUM(TableOfDifferences.CostRevaluationReserve) <> 0
	|		OR SUM(TableOfDifferences.CostRevaluationReserveLocal) <> 0
	|		OR SUM(TableOfDifferences.CostGainMA) <> 0
	|		OR SUM(TableOfDifferences.CostGainLocal) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Period              AS Period,
	|	Table.Organization         AS Organization,
	|	Table.IntangibleAsset AS AccountingObject,
	|	&Recorder                AS Document
	|INTO CostOfNMA_AssignmentsForCalculatingCostOfVNAUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IACostBeforeWrite AS TableBeforeWrite
	|	WHERE
	|		TableBeforeWrite.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|					VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|					VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost),
	|					VALUE(Enum.BusinessTransactions.VATAllocation))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		AccumulationRegister.IACost AS TableWhenWriting
	|	WHERE
	|		TableWhenWriting.Recorder = &Recorder
	|		AND TableWhenWriting.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
	|					VALUE(Enum.BusinessTransactions.IntangibleAssetImprovement),
	|					VALUE(Enum.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost),
	|					VALUE(Enum.BusinessTransactions.VATAllocation))
	|	) AS Table
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IACostBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IACostUpdate", Selection.Next() And Selection.Count > 0);
	
	Selection = QueryResult[1].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"CostOfNMA_AssignmentsForCalculatingCostOfVNAUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

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
		|	InitialEntries.IntangibleAsset AS IntangibleAsset,
		|	InitialEntries.Cost AS Cost,
		|	InitialEntries.CostRevaluationReserve AS CostRevaluationReserve
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.IACost AS InitialEntries
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
		|		InitialEntries.IntangibleAsset AS IntangibleAsset,
		|		InitialEntries.Cost AS Cost,
		|		InitialEntries.CostRevaluationReserve AS CostRevaluationReserve
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
		|		Records.IntangibleAsset AS IntangibleAsset,
		|		-Records.Cost AS Cost,
		|		-Records.CostRevaluationReserve AS CostRevaluationReserve
		|	FROM
		|		AccumulationRegister.IACost AS Records
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
		|	Table.IntangibleAsset
		|HAVING
		|	SUM(Table.Cost) <> 0 OR SUM(Table.CostRevaluationReserve) <> 0
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
