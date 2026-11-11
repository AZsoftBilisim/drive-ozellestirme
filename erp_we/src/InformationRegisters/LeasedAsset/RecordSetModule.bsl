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
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.Organization AS Organization,
	|	TableBeforeWrite.Partner AS Partner,
	|	TableBeforeWrite.Counterparty AS Counterparty,
	|	TableBeforeWrite.Contract AS Contract,
	|	TableBeforeWrite.Cost AS Cost,
	|	TableBeforeWrite.State AS State
	|INTO LeasedAssetBeforeWrite
	|FROM
	|	InformationRegister.LeasedAsset AS TableBeforeWrite
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
	"SELECT
	|	&Recorder               AS Document,
	|	Table.Period             AS Period,
	|	Table.FixedAsset   AS FixedAsset,
	|	Table.Organization        AS Organization,
	|	Table.Contract            AS Contract,
	|	TRUE                     AS RecordInLocalAccounting,
	|	TRUE                     AS RecordInManAccounting
	|
	|INTO LeasedAssetUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.Contract           AS Contract
	|	FROM
	|		LeasedAssetBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.LeasedAsset AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Recorder = &Recorder
	|
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.Partner <> TableBeforeWrite.Partner
	|				OR TableWhenWriting.Counterparty <> TableBeforeWrite.Counterparty
	|				OR TableWhenWriting.Contract <> TableBeforeWrite.Contract
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR TableWhenWriting.Cost <> TableBeforeWrite.Cost
	|				OR TableWhenWriting.State <> TableBeforeWrite.State)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.FixedAsset,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.Contract
	|	FROM
	|		InformationRegister.LeasedAsset AS TableWhenWriting
	|
	|			LEFT JOIN LeasedAssetBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.Partner <> TableBeforeWrite.Partner
	|				OR TableWhenWriting.Counterparty <> TableBeforeWrite.Counterparty
	|				OR TableWhenWriting.Contract <> TableBeforeWrite.Contract
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR TableWhenWriting.Cost <> TableBeforeWrite.Cost
	|				OR TableWhenWriting.State <> TableBeforeWrite.State)
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.FixedAsset,
	|	Table.Organization,
	|	Table.Contract";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	RegisterName = "LeasedAsset";
	
	Query.Text = Query.Text + Common.QueryBatchSeparator() + "DROP " + RegisterName + "BeforeWrite";
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"LeasedAssetUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure
 
#EndRegion

#EndIf
