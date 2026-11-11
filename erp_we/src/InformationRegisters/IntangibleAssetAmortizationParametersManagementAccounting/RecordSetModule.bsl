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
	|	TableBeforeWrite.UsefulLifeMonths AS UsefulLifeMonths,
	|	TableBeforeWrite.AccelerationFactor AS AccelerationFactor,
	|	TableBeforeWrite.DepreciationMethod AS DepreciationMethod,
	|	TableBeforeWrite.ResidualValueMan AS ResidualValueMan
	|INTO IntangibleAssetAmortizationParametersManagementAccountingBeforeWrite
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS TableBeforeWrite
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
	|	FALSE                        AS RecordInLocalAccounting,
	|	TRUE                      AS RecordInManAccounting,
	|	&Recorder                AS Document
	|INTO IntangibleAssetAmortizationParametersManagementAccountingUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IntangibleAssetAmortizationParametersManagementAccountingBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeMonths <> TableBeforeWrite.UsefulLifeMonths
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.DepreciationMethod <> TableBeforeWrite.DepreciationMethod
	|				OR TableWhenWriting.ResidualValueMan <> TableBeforeWrite.ResidualValueMan
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS TableWhenWriting
	|
	|			LEFT JOIN IntangibleAssetAmortizationParametersManagementAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeMonths <> TableBeforeWrite.UsefulLifeMonths
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.DepreciationMethod <> TableBeforeWrite.DepreciationMethod
	|				OR TableWhenWriting.ResidualValueMan <> TableBeforeWrite.ResidualValueMan
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IntangibleAssetAmortizationParametersManagementAccountingBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IntangibleAssetAmortizationParametersManagementAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure
 
#EndRegion

#EndIf
