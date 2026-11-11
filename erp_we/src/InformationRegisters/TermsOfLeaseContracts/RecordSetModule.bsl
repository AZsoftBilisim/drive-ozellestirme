#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

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
	|	TableBeforeWrite.Contract AS Contract,
	|	TableBeforeWrite.State AS State
	|INTO TableBeforeWrite
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TableBeforeWrite
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
	|	&Recorder AS Document,
	|	TableBeforeWrite.Contract.Organization AS Organization,
	|	TableBeforeWrite.Period AS Period
	|INTO TermsOfLeaseContractsUpdate
	|FROM
	|	TableBeforeWrite AS TableBeforeWrite
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TableWhenWriting
	|		ON TableWhenWriting.Contract = TableBeforeWrite.Contract
	|			AND TableWhenWriting.Recorder = &Recorder
	|WHERE
	|	(TableWhenWriting.Period IS NULL
	|		OR TableWhenWriting.State <> TableBeforeWrite.State
	|		OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|
	|UNION ALL
	|
	|SELECT
	|	&Recorder,
	|	TableWhenWriting.Contract.Organization,
	|	TableWhenWriting.Period
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TableWhenWriting
	|		LEFT JOIN TableBeforeWrite AS TableBeforeWrite
	|		ON TableWhenWriting.Contract = TableBeforeWrite.Contract
	|WHERE
	|	(TableBeforeWrite.Period IS NULL
	|		OR TableWhenWriting.State <> TableBeforeWrite.State
	|		OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|	AND TableWhenWriting.Recorder = &Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"TermsOfLeaseContractsUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf