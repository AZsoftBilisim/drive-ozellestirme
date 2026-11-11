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
	|	TableBeforeWrite.ChangeDate AS ChangeDate,
	|	TableBeforeWrite.Contract AS Contract,
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.Date AS Date,
	|	TableBeforeWrite.Interests AS Interests
	|INTO TableBeforeWrite
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|INDEX BY
	|	Contract,
	|	FixedAsset,
	|	Date
	|";
	
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
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.ChangeDate AS Period
	|INTO ScheduleOfInterestChargesOnIncomeRentalUpdate
	|FROM
	|	TableBeforeWrite AS TableBeforeWrite
	|		LEFT JOIN InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS TableWhenWriting
	|		ON TableWhenWriting.Contract = TableBeforeWrite.Contract
	|			AND TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|			AND TableWhenWriting.Date = TableBeforeWrite.Date
	|			AND TableWhenWriting.Recorder = &Recorder
	|WHERE
	|	(TableWhenWriting.Contract IS NULL
	|		OR TableWhenWriting.Interests <> TableBeforeWrite.Interests
	|		OR BEGINOFPERIOD(TableWhenWriting.ChangeDate, DAY) <> BEGINOFPERIOD(TableBeforeWrite.ChangeDate, DAY))
	|
	|UNION ALL
	|
	|SELECT
	|	&Recorder,
	|	TableWhenWriting.Contract.Organization,
	|	TableWhenWriting.FixedAsset,
	|	TableWhenWriting.ChangeDate
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS TableWhenWriting
	|		LEFT JOIN TableBeforeWrite AS TableBeforeWrite
	|		ON TableWhenWriting.Contract = TableBeforeWrite.Contract
	|			AND TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|			AND TableWhenWriting.Date = TableBeforeWrite.Date
	|WHERE
	|	(TableBeforeWrite.Contract IS NULL
	|		OR TableWhenWriting.Interests <> TableBeforeWrite.Interests
	|		OR BEGINOFPERIOD(TableWhenWriting.ChangeDate, DAY) <> BEGINOFPERIOD(TableBeforeWrite.ChangeDate, DAY))
	|	AND TableWhenWriting.Recorder = &Recorder
	|INDEX BY
	|	FixedAsset,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"ScheduleOfInterestChargesOnIncomeRentalUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf