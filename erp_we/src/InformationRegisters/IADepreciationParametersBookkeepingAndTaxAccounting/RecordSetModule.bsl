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
	|	TableBeforeWrite.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	TableBeforeWrite.UsefulLifeMonthsTA AS UsefulLifeMonthsTA,
	|	TableBeforeWrite.DepreciationAccrualFactor AS DepreciationAccrualFactor
	|INTO IADepreciationParametersBookkeepingAndTaxAccountingBeforeWrite
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting AS TableBeforeWrite
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
	|INTO IADepreciationParametersBookkeepingAndTaxAccountingUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IADepreciationParametersBookkeepingAndTaxAccountingBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeMonthsAC <> TableBeforeWrite.UsefulLifeMonthsAC
	|				OR TableWhenWriting.UsefulLifeMonthsTA <> TableBeforeWrite.UsefulLifeMonthsTA
	|				OR TableWhenWriting.DepreciationAccrualFactor <> TableBeforeWrite.DepreciationAccrualFactor
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting AS TableWhenWriting
	|			LEFT JOIN IADepreciationParametersBookkeepingAndTaxAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeMonthsAC <> TableBeforeWrite.UsefulLifeMonthsAC
	|				OR TableWhenWriting.UsefulLifeMonthsTA <> TableBeforeWrite.UsefulLifeMonthsTA
	|				OR TableWhenWriting.DepreciationAccrualFactor <> TableBeforeWrite.DepreciationAccrualFactor
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IADepreciationParametersBookkeepingAndTaxAccountingBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IADepreciationParametersBookkeepingAndTaxAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf

