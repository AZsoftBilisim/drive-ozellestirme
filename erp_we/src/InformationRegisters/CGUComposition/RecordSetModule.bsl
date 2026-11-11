#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DeleteImpairmentAssignmentsInFuturePeriods();
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

Procedure DeleteImpairmentAssignmentsInFuturePeriods()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	JobsForMonthEndClosing.Month        AS Month,
	|	JobsForMonthEndClosing.Operation     AS Operation,
	|	JobsForMonthEndClosing.Organization  AS Organization,
	|	JobsForMonthEndClosing.JobNumber AS JobNumber,
	|	JobsForMonthEndClosing.Document     AS Document
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|WHERE
	|	JobsForMonthEndClosing.Document = &Document
	|	AND JobsForMonthEndClosing.Month  > &Month
	|	AND JobsForMonthEndClosing.Operation = &Operation";
	
	Query.SetParameter("Document", ThisObject.Filter.Recorder.Value);
	DocumentDate = Common.ObjectAttributeValue(ThisObject.Filter.Recorder.Value, "Date");
	
	Query.SetParameter("Month",    BegOfMonth(DocumentDate));
	Query.SetParameter("Operation", Catalogs.MonthEndClosingOperations.ImpairmentFA);
	
	TasksThatAreBeingDeleted = Query.Execute();
	
	If TasksThatAreBeingDeleted.IsEmpty() Then
		Return;
	EndIf;
	
	DeletedTasksSelection = TasksThatAreBeingDeleted.Select();
	While DeletedTasksSelection.Next() Do
		Task_To_Delete = InformationRegisters.JobsForMonthEndClosing.CreateRecordManager();
		FillPropertyValues(Task_To_Delete, DeletedTasksSelection);
		Task_To_Delete.Delete();
	EndDo;
	
EndProcedure

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Period            AS Period,
	|	TableBeforeWrite.Organization       AS Organization,
	|	TableBeforeWrite.NonCurrentAsset AS NonCurrentAsset,
	|	TableBeforeWrite.CGU              AS CGU
	|INTO CGUCompositionBeforeWrite
	|FROM
	|	InformationRegister.CGUComposition AS TableBeforeWrite
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
	|	Table.Period            AS Period,
	|	Table.Organization       AS Organization,
	|	Table.NonCurrentAsset AS NonCurrentAsset,
	|	Table.CGU              AS CGU,
	|	&Recorder              AS Document
	|INTO CGUCompositionUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.NonCurrentAsset AS NonCurrentAsset,
	|		TableBeforeWrite.CGU              AS CGU
	|	FROM
	|		CGUCompositionBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN InformationRegister.CGUComposition AS TableWhenWriting
	|			ON TableWhenWriting.NonCurrentAsset = TableBeforeWrite.NonCurrentAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|	WHERE
	|		(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.CGU <> TableBeforeWrite.CGU
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.NonCurrentAsset,
	|		TableWhenWriting.CGU
	|	FROM
	|		InformationRegister.CGUComposition AS TableWhenWriting
	|			LEFT JOIN CGUCompositionBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.NonCurrentAsset = TableBeforeWrite.NonCurrentAsset
	|			AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|	WHERE
	|		(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.CGU <> TableBeforeWrite.CGU
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, DAY) <> BEGINOFPERIOD(TableBeforeWrite.Period, DAY))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.NonCurrentAsset,
	|		TableWhenWriting.CGU
	|	FROM
	|		InformationRegister.CGUComposition AS TableWhenWriting
	|			INNER JOIN CGUCompositionBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.NonCurrentAsset = TableBeforeWrite.NonCurrentAsset
	|	WHERE
	|			TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|			AND TableWhenWriting.Recorder = &Recorder
	|	) AS Table
	|;
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"CGUCompositionUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
