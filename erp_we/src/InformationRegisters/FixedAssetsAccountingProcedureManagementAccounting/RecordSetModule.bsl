#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
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
	|	TableBeforeWrite.Period AS Period,
	|	TableBeforeWrite.Organization AS Organization,
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.State AS State,
	|	TableBeforeWrite.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	TableBeforeWrite.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	TableBeforeWrite.ExpenseItem AS ExpenseItem,
	|	TableBeforeWrite.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableBeforeWrite.Department AS Department,
	|	TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|	TableBeforeWrite.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TableBeforeWrite.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|INTO FixedAssetsAccountingProcedureManagementAccountingBeforeWrite
	|
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|	AND TableBeforeWrite.CorrectionDate = DATETIME(1,1,1)";
	
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
	|	Table.Period           AS Period,
	|	Table.Organization      AS Organization,
	|	Table.FixedAsset AS FixedAsset,
	|	FALSE                     AS RecordInLocalAccounting,
	|	TRUE                   AS RecordInManAccounting,
	|	&Recorder             AS Document
	|
	|INTO FixedAssetsAccountingProcedureManagementAccountingUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset
	|	FROM
	|		FixedAssetsAccountingProcedureManagementAccountingBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.AccrueDepreciationOrAmortization <> TableBeforeWrite.AccrueDepreciationOrAmortization
	|				OR TableWhenWriting.DepreciationRecordMethod <> TableBeforeWrite.DepreciationRecordMethod
	|				OR TableWhenWriting.ExpenseItem <> TableBeforeWrite.ExpenseItem
	|				OR TableWhenWriting.DimensionOfExpenses <> TableBeforeWrite.DimensionOfExpenses
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset
	|	FROM
	|		InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS TableWhenWriting
	|
	|			LEFT JOIN FixedAssetsAccountingProcedureManagementAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.AccrueDepreciationOrAmortization <> TableBeforeWrite.AccrueDepreciationOrAmortization
	|				OR TableWhenWriting.DepreciationRecordMethod <> TableBeforeWrite.DepreciationRecordMethod
	|				OR TableWhenWriting.ExpenseItem <> TableBeforeWrite.ExpenseItem
	|				OR TableWhenWriting.DimensionOfExpenses <> TableBeforeWrite.DimensionOfExpenses
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses)
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FixedAssetsAccountingProcedureManagementAccountingBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"FixedAssetsAccountingProcedureManagementAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
