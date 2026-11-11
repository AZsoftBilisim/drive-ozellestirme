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
	|	TableBeforeWrite.FixedAssetsLocation AS FixedAssetsLocation,
	|	TableBeforeWrite.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TableBeforeWrite.RecordInManAccounting AS RecordInManAccounting
	|INTO FALocationBeforeWrite
	|FROM
	|	InformationRegister.FALocation AS TableBeforeWrite
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
	|	Table.Period              AS Period,
	|	Table.Organization         AS Organization,
	|	Table.FixedAsset    AS FixedAsset,
	|	Table.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|	Table.RecordInManAccounting   AS RecordInManAccounting,
	|	&Recorder                AS Document
	|INTO FALocationUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period              AS Period,
	|		TableBeforeWrite.Organization         AS Organization,
	|		TableBeforeWrite.FixedAsset    AS FixedAsset,
	|		TableBeforeWrite.RecordInLocalAccounting  AS RecordInLocalAccounting,
	|		TableBeforeWrite.RecordInManAccounting   AS RecordInManAccounting
	|	FROM
	|		FALocationBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.FALocation AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.FixedAssetsLocation <> TableBeforeWrite.FixedAssetsLocation)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset,
	|		TableWhenWriting.RecordInLocalAccounting,
	|		TableWhenWriting.RecordInManAccounting
	|	FROM
	|		InformationRegister.FALocation AS TableWhenWriting
	|			LEFT JOIN FALocationBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND BEGINOFPERIOD(TableWhenWriting.Period, DAY) = BEGINOFPERIOD(TableBeforeWrite.Period, DAY)
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.FixedAssetsLocation <> TableBeforeWrite.FixedAssetsLocation)
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP FALocationBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"FALocationUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
