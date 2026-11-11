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
	|	TableBeforeWrite.UsefulLifeMonths AS UsefulLifeMonths,
	|	TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	TableBeforeWrite.AccelerationFactor AS AccelerationFactor,
	|	TableBeforeWrite.DepreciationMethod AS DepreciationMethod,
	|	TableBeforeWrite.ResidualValueMan AS ResidualValueMan,
	|	TableBeforeWrite.LastChangeDate AS LastChangeDate,
	|	TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|INTO FixedAssetDepreciationParametersManagementAccountingBeforeWrite
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS TableBeforeWrite
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
	|INTO FixedAssetDepreciationParametersManagementAccountingUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset
	|	FROM
	|		FixedAssetDepreciationParametersManagementAccountingBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeForCalculatingDepreciationMonth <> TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.DepreciationMethod <> TableBeforeWrite.DepreciationMethod
	|				OR TableWhenWriting.ResidualValueMan <> TableBeforeWrite.ResidualValueMan
	|				OR TableWhenWriting.LastChangeDate <> TableBeforeWrite.LastChangeDate
	|				OR TableWhenWriting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits <> TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset
	|	FROM
	|		InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS TableWhenWriting
	|			LEFT JOIN FixedAssetDepreciationParametersManagementAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.UsefulLifeForCalculatingDepreciationMonth <> TableBeforeWrite.UsefulLifeForCalculatingDepreciationMonth
	|				OR TableWhenWriting.AccelerationFactor <> TableBeforeWrite.AccelerationFactor
	|				OR TableWhenWriting.DepreciationMethod <> TableBeforeWrite.DepreciationMethod
	|				OR TableWhenWriting.ResidualValueMan <> TableBeforeWrite.ResidualValueMan
	|				OR TableWhenWriting.LastChangeDate <> TableBeforeWrite.LastChangeDate
	|				OR TableWhenWriting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits <> TableBeforeWrite.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits)
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FixedAssetDepreciationParametersManagementAccountingBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"FixedAssetDepreciationParametersManagementAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
