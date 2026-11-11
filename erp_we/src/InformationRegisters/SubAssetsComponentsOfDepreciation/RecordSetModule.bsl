#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	For Each Record In ThisObject Do
		If Not ValueIsFilled(Record.RowID) Then
			Record.RowID = New UUID;
		EndIf;
	EndDo;

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
	|	TableBeforeWrite.Period              AS Period,
	|	TableBeforeWrite.SubAssetComponent       AS SubAssetComponent,
	|	TableBeforeWrite.FixedAsset    AS FixedAsset
	|INTO SubAssetsComponentsOfDepreciationBeforeWrite
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation AS TableBeforeWrite
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
	|	&Organization                AS Organization, // for compatibility with other tables
	|	Table.SubAssetComponent       AS SubAssetComponent,
	|	Table.FixedAsset    AS FixedAsset,
	|	&Recorder                AS Document
	|INTO SubAssetsComponentsOfDepreciationUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period              AS Period,
	|		TableBeforeWrite.SubAssetComponent       AS SubAssetComponent,
	|		TableBeforeWrite.FixedAsset    AS FixedAsset
	|	FROM
	|		SubAssetsComponentsOfDepreciationBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS TableWhenWriting
	|			ON TableWhenWriting.SubAssetComponent = TableBeforeWrite.SubAssetComponent
	|				AND TableWhenWriting.Recorder = &Recorder
	|	WHERE
	|		(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.FixedAsset <> TableBeforeWrite.FixedAsset
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableWhenWriting.Period              AS Period,
	|		TableWhenWriting.SubAssetComponent       AS SubAssetComponent,
	|		TableWhenWriting.FixedAsset    AS FixedAsset
	|	FROM
	|		InformationRegister.SubAssetsComponentsOfDepreciation AS TableWhenWriting
	|			LEFT JOIN SubAssetsComponentsOfDepreciationBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.SubAssetComponent = TableBeforeWrite.SubAssetComponent
	|	WHERE
	|		(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.FixedAsset <> TableBeforeWrite.FixedAsset
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder) AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SubAssetsComponentsOfDepreciationBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("Organization", Filter.Recorder.Value.Organization);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"SubAssetsComponentsOfDepreciationUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf