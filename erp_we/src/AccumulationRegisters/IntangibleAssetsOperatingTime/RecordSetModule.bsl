#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Period,
	|	TableBeforeWrite.IntangibleAsset,
	|	TableBeforeWrite.Organization,
	|	TableBeforeWrite.Count
	|INTO IntangibleAssetsOperatingTimeBeforeWrite
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	ChangesTable.Organization          AS Organization,
	|	ChangesTable.IntangibleAsset  AS IntangibleAsset,
	|	&Recorder                          AS Document,
	|	TRUE                                AS RecordInLocalAccounting,
	|	TRUE                                AS RecordInManAccounting,
	|	MIN(ChangesTable.Period)      AS Period
	|INTO IntangibleAssetsOperatingTimeUpdate
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(Table.Period, MONTH) AS Period,
	|		Table.Organization AS Organization,
	|		Table.IntangibleAsset AS IntangibleAsset,
	|		Table.Count AS CountUpdate
	|	FROM
	|		IntangibleAssetsOperatingTimeBeforeWrite AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(Table.Period, MONTH),
	|		Table.Organization,
	|		Table.IntangibleAsset,
	|		-Table.Count
	|	FROM
	|		AccumulationRegister.IntangibleAssetsOperatingTime AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.IntangibleAsset
	|
	|HAVING
	|	SUM(ChangesTable.CountUpdate) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IntangibleAssetsOperatingTimeBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IntangibleAssetsOperatingTimeUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
