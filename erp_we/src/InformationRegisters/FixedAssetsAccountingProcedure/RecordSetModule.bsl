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
	|	TableBeforeWrite.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|	TableBeforeWrite.RunningTimeValue AS RunningTimeValue,
	|	TableBeforeWrite.EstimatedRunningTime AS EstimatedRunningTime
	|INTO FixedAssetsAccountingProcedureBeforeWrite
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS TableBeforeWrite
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
	|	TRUE                   AS RecordInLocalAccounting,
	|	FALSE                     AS RecordInManAccounting,
	|	&Recorder             AS Document
	|INTO FixedAssetsAccountingProcedureUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset
	|	FROM
	|		FixedAssetsAccountingProcedureBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.FinancialAccountingGroup <> TableBeforeWrite.FinancialAccountingGroup
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.RunningTimeValue <> TableBeforeWrite.RunningTimeValue
	|				OR TableWhenWriting.EstimatedRunningTime <> TableBeforeWrite.EstimatedRunningTime
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset
	|	FROM
	|		InformationRegister.FixedAssetsAccountingProcedure AS TableWhenWriting
	|			LEFT JOIN FixedAssetsAccountingProcedureBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.FinancialAccountingGroup <> TableBeforeWrite.FinancialAccountingGroup
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.RunningTimeValue <> TableBeforeWrite.RunningTimeValue
	|				OR TableWhenWriting.EstimatedRunningTime <> TableBeforeWrite.EstimatedRunningTime
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FixedAssetsAccountingProcedureBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"FixedAssetsAccountingProcedureUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
