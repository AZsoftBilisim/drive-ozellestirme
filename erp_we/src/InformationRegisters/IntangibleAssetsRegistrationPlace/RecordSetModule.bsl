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
	|	TableBeforeWrite.Department AS Department,
	|	TableBeforeWrite.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TableBeforeWrite.RecordInManAccounting AS RecordInManAccounting
	|INTO IntangibleAssetsRegistrationPlaceBeforeWrite
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace AS TableBeforeWrite
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
	|	Table.Period                 AS Period,
	|	Table.Organization            AS Organization,
	|	Table.IntangibleAsset    AS IntangibleAsset,
	|	Table.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	Table.RecordInManAccounting      AS RecordInManAccounting,
	|	&Recorder                   AS Document
	|INTO IntangibleAssetsRegistrationPlaceUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period                 AS Period,
	|		TableBeforeWrite.Organization            AS Organization,
	|		TableBeforeWrite.IntangibleAsset    AS IntangibleAsset,
	|		TableBeforeWrite.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|		TableBeforeWrite.RecordInManAccounting      AS RecordInManAccounting
	|	FROM
	|		IntangibleAssetsRegistrationPlaceBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset,
	|		TableWhenWriting.RecordInLocalAccounting,
	|		TableWhenWriting.RecordInManAccounting
	|	FROM
	|		InformationRegister.IntangibleAssetsRegistrationPlace AS TableWhenWriting
	|			LEFT JOIN IntangibleAssetsRegistrationPlaceBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.Department <> TableBeforeWrite.Department
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IntangibleAssetsRegistrationPlaceBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IntangibleAssetsRegistrationPlaceUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
