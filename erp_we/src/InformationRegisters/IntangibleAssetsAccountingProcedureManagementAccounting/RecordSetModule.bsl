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
	|	TableBeforeWrite.IntangibleAsset AS IntangibleAsset,
	|	TableBeforeWrite.AccrueDepreciationOrAmortization AS AccrueDepreciationOrAmortization,
	|	TableBeforeWrite.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	TableBeforeWrite.ExpenseItem AS ExpenseItem,
	|	TableBeforeWrite.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableBeforeWrite.Department AS Department,
	|	TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|	TableBeforeWrite.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TableBeforeWrite.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|INTO IntangibleAssetsAccountingProcedureManagementAccountingBeforeWrite
	|
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS TableBeforeWrite
	|
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|";
	
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
	|	Table.Period              AS Period,
	|	Table.Organization         AS Organization,
	|	Table.IntangibleAsset AS IntangibleAsset,
	|	FALSE                        AS RecordInLocalAccounting,
	|	TRUE                      AS RecordInManAccounting,
	|	&Recorder                AS Document
	|
	|INTO IntangibleAssetsAccountingProcedureManagementAccountingUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IntangibleAssetsAccountingProcedureManagementAccountingBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.AccrueDepreciationOrAmortization <> TableBeforeWrite.AccrueDepreciationOrAmortization
	|				OR TableWhenWriting.DepreciationRecordMethod <> TableBeforeWrite.DepreciationRecordMethod
	|				OR TableWhenWriting.ExpenseItem <> TableBeforeWrite.ExpenseItem
	|				OR TableWhenWriting.DimensionOfExpenses <> TableBeforeWrite.DimensionOfExpenses
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS TableWhenWriting
	|
	|			LEFT JOIN IntangibleAssetsAccountingProcedureManagementAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.AccrueDepreciationOrAmortization <> TableBeforeWrite.AccrueDepreciationOrAmortization
	|				OR TableWhenWriting.DepreciationRecordMethod <> TableBeforeWrite.DepreciationRecordMethod
	|				OR TableWhenWriting.ExpenseItem <> TableBeforeWrite.ExpenseItem
	|				OR TableWhenWriting.DimensionOfExpenses <> TableBeforeWrite.DimensionOfExpenses
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IntangibleAssetsAccountingProcedureManagementAccountingBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IntangibleAssetsAccountingProcedureManagementAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
