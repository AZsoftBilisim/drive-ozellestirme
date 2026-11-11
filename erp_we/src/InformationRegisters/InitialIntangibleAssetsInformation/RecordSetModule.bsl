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
	|	TableBeforeWrite.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	TableBeforeWrite.DepreciationMethodTaxAccounting AS DepreciationMethodTaxAccounting,
	|	TableBeforeWrite.DateOfRecognitionManagementAccounting AS DateOfRecognitionManagementAccounting,
	|	TableBeforeWrite.DateOfRecognitionAccounting AS DateOfRecognitionAccounting,
	|	TableBeforeWrite.AccountingProcedureTA AS AccountingProcedureTA
	|INTO InitialIntangibleAssetsInformationBeforeWrite
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS TableBeforeWrite
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
	|	Table.Period                AS Period,
	|	Table.Organization           AS Organization,
	|	Table.IntangibleAsset   AS IntangibleAsset,
	|	Table.RecordInLocalAccounting    AS RecordInLocalAccounting,
	|	Table.RecordInManAccounting     AS RecordInManAccounting,
	|	&Recorder                  AS Document
	|INTO InitialIntangibleAssetsInformationUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset,
	|		TableBeforeWrite.DateOfRecognitionAccounting <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|		TableBeforeWrite.DateOfRecognitionManagementAccounting <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|	FROM
	|		InitialIntangibleAssetsInformationBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|				OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|				OR BEGINOFPERIOD(TableWhenWriting.DateOfRecognitionAccounting, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.DateOfRecognitionAccounting, MONTH)
	|				OR BEGINOFPERIOD(TableWhenWriting.DateOfRecognitionManagementAccounting, DAY) <> BEGINOFPERIOD(TableBeforeWrite.DateOfRecognitionManagementAccounting, DAY))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset,
	|		TableWhenWriting.DateOfRecognitionAccounting <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|		TableWhenWriting.DateOfRecognitionManagementAccounting <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|	FROM
	|		InformationRegister.InitialIntangibleAssetsInformation AS TableWhenWriting
	|			LEFT JOIN InitialIntangibleAssetsInformationBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.AccountingProcedureTA <> TableBeforeWrite.AccountingProcedureTA
	|				OR TableWhenWriting.DepreciationMethodAccounting <> TableBeforeWrite.DepreciationMethodAccounting
	|				OR BEGINOFPERIOD(TableWhenWriting.DateOfRecognitionAccounting, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.DateOfRecognitionAccounting, MONTH)
	|				OR BEGINOFPERIOD(TableWhenWriting.DateOfRecognitionManagementAccounting, DAY) <> BEGINOFPERIOD(TableBeforeWrite.DateOfRecognitionManagementAccounting, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Text = Query.Text + Common.QueryBatchSeparator() + "DROP InitialIntangibleAssetsInformationBeforeWrite";
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"InitialIntangibleAssetsInformationUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
