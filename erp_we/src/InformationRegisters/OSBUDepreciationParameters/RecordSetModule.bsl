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
	|	TableBeforeWrite.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	TableBeforeWrite.AccelerationFactor AS AccelerationFactor,
	|	TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	TableBeforeWrite.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation,
	|	TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	TableBeforeWrite.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	TableBeforeWrite.LastChangeDate AS LastChangeDate
	|INTO OSBUDepreciationParametersBeforeWrite
	|FROM
	|	InformationRegister.OSBUDepreciationParameters AS TableBeforeWrite
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
	|INTO OSBUDepreciationParametersUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset
	|	FROM
	|		OSBUDepreciationParametersBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.OSBUDepreciationParameters AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.AnnualDepreciationRate <> TableBeforeWrite.AnnualDepreciationRate
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits <> TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|				OR TableWhenWriting.PermanentDifferencesUsedToCalculateDepreciation <> TableBeforeWrite.PermanentDifferencesUsedToCalculateDepreciation
	|				OR TableWhenWriting.UsefulLifeForCalculatingDepreciationMonth <> TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth
	|				OR TableWhenWriting.CostUsedToCalculateDepreciationManag <> TableBeforeWrite.CostUsedToCalculateDepreciationManag
	|				OR TableWhenWriting.LastChangeDate <> TableBeforeWrite.LastChangeDate)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset
	|	FROM
	|		InformationRegister.OSBUDepreciationParameters AS TableWhenWriting
	|			LEFT JOIN OSBUDepreciationParametersBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.AnnualDepreciationRate <> TableBeforeWrite.AnnualDepreciationRate
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits <> TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|				OR TableWhenWriting.PermanentDifferencesUsedToCalculateDepreciation <> TableBeforeWrite.PermanentDifferencesUsedToCalculateDepreciation
	|				OR TableWhenWriting.UsefulLifeForCalculatingDepreciationMonth <> TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth
	|				OR TableWhenWriting.CostUsedToCalculateDepreciationManag <> TableBeforeWrite.CostUsedToCalculateDepreciationManag
	|				OR TableWhenWriting.LastChangeDate <> TableBeforeWrite.LastChangeDate)
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OSBUDepreciationParametersBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"OSBUDepreciationParametersUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
