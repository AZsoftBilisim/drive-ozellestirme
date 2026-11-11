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
	|	TableBeforeWrite.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableBeforeWrite.LineOfBusiness AS LineOfBusiness,
	|	TableBeforeWrite.EstimatedRunningTime AS EstimatedRunningTime
	|INTO IntangibleAssetsAccountingProcedureBeforeWrite
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS TableBeforeWrite
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
	|	Table.Period              AS Period,
	|	Table.Organization         AS Organization,
	|	Table.IntangibleAsset AS IntangibleAsset,
	|	TRUE                      AS RecordInLocalAccounting,
	|	FALSE                        AS RecordInManAccounting,
	|	&Recorder                AS Document
	|INTO IntangibleAssetsAccountingProcedureUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IntangibleAssetsAccountingProcedureBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedure AS TableWhenWriting
	|			ON TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.FinancialAccountingGroup <> TableBeforeWrite.FinancialAccountingGroup
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.EstimatedRunningTime <> TableBeforeWrite.EstimatedRunningTime
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		InformationRegister.IntangibleAssetsAccountingProcedure AS TableWhenWriting
	|			LEFT JOIN IntangibleAssetsAccountingProcedureBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.FinancialAccountingGroup <> TableBeforeWrite.FinancialAccountingGroup
	|				OR TableWhenWriting.LineOfBusiness <> TableBeforeWrite.LineOfBusiness
	|				OR TableWhenWriting.EstimatedRunningTime <> TableBeforeWrite.EstimatedRunningTime
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IntangibleAssetsAccountingProcedureBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IntangibleAssetsAccountingProcedureUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
