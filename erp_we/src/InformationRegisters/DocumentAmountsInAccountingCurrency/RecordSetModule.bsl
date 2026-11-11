#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueueDuringExchange();
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		// The current state of the set is placed in a temporary table
		// in order to get a change in the new set relative to the current one when writing.
		
		Query = New Query("SELECT
		|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
		|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
		|	DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
		|	DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
		|	DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP,
		|	DocumentAmountsInAccountingCurrency.Period AS Period,
		|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
		|	DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
		|	DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|	DocumentAmountsInAccountingCurrency.VATBaseLocal AS VATBaseLocal,
		|	DocumentAmountsInAccountingCurrency.VATAmountCompl AS VATAmountCompl,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATMan AS AmountExcludingVATMan,
		|	DocumentAmountsInAccountingCurrency.VATAmountMan AS VATAmountMan,
		|	DocumentAmountsInAccountingCurrency.AmountGiven AS AmountGiven,
		|	DocumentAmountsInAccountingCurrency.AmountGivenCompl AS AmountGivenCompl,
		|	DocumentAmountsInAccountingCurrency.AmountGivenMan AS AmountGivenMan,
		|	DocumentAmountsInAccountingCurrency.Currency AS Currency,
		|	DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
		|	DocumentAmountsInAccountingCurrency.VATBasePeriod AS VATBasePeriod,
		|	DocumentAmountsInAccountingCurrency.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|	DocumentAmountsInAccountingCurrency.PaymentType_ AS PaymentType_
		|INTO DocumentAmountsInAccountingCurrencyBeforeWrite
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|WHERE
		|	DocumentAmountsInAccountingCurrency.Recorder = &Recorder
		|	AND NOT &IsNew
		|	AND NOT &DataExchange
		|");
		
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		If AdditionalProperties.Property("DocumentProperties") Then
			Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
		Else
			Query.SetParameter("IsNew", False);
		EndIf;
		If AdditionalProperties.Property("TempTablesManager") Then
			Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Else
			Query.TempTablesManager = New TempTablesManager;
			AdditionalProperties.Insert("TempTablesManager", Query.TempTablesManager);
		EndIf;
		Query.SetParameter("DataExchange", DataExchange.Load);

		Query.Execute();
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	If NewOnlineARAPAccounting Then
		
		Query = New Query;
		
		ArrayOfRequestTexts = New Array;
		QueryText = 
		"SELECT
		|	Table.Period AS Period,
		|	Table.Recorder AS Recorder,
		|	Table.RowID AS RowID,
		|	Table.VATRate AS VATRate,
		|	Table.ARAPObject AS ARAPObject,
		|	Table.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|	&CreateTasksByEndOfNextMonth AS CreateTasksByEndOfNextMonth
		|INTO AmountsOfDocumentsInCurrenciesOfChangeAccounting
		|FROM
		|	(SELECT
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.Recorder AS Recorder,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.RowID AS RowID,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountExcludingVAT AS AmountExcludingVAT,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATAmount AS VATAmount,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountARAP AS AmountARAP,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountVATARAP AS AmountVATARAP,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.Period AS Period,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATRate AS VATRate,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.ARAPObject AS ARAPObject,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData
		|	FROM
		|		DocumentAmountsInAccountingCurrencyBeforeWrite AS DocumentAmountsInAccountingCurrencyBeforeWrite
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentAmountsInAccountingCurrency.Recorder,
		|		DocumentAmountsInAccountingCurrency.RowID,
		|		-DocumentAmountsInAccountingCurrency.AmountExcludingVAT,
		|		-DocumentAmountsInAccountingCurrency.VATAmount,
		|		-DocumentAmountsInAccountingCurrency.AmountARAP,
		|		-DocumentAmountsInAccountingCurrency.AmountVATARAP,
		|		DocumentAmountsInAccountingCurrency.Period,
		|		DocumentAmountsInAccountingCurrency.VATRate,
		|		DocumentAmountsInAccountingCurrency.ARAPObject,
		|		DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData
		|	FROM
		|		InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|	WHERE
		|		DocumentAmountsInAccountingCurrency.Recorder = &Recorder) AS Table
		|		LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|		ON Table.Recorder = SourceDocumentsData.Document
		|
		|GROUP BY
		|	Table.RowID,
		|	Table.Recorder,
		|	Table.ARAPObject,
		|	Table.Period,
		|	Table.VATRate,
		|	Table.RecalculateBasedOnARAPData
		|
		|HAVING
		|	SUM(Table.AmountExcludingVAT) <> 0
		|	OR SUM(Table.VATAmount) <> 0
		|	OR SUM(Table.AmountARAP) <> 0
		|	OR SUM(Table.AmountVATARAP) <> 0
		|";
		ArrayOfRequestTexts.Add(QueryText);
		
		ArrayOfRequestTexts.Add("DROP DocumentAmountsInAccountingCurrencyBeforeWrite");
		
		Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.SetParameter("CreateTasksByEndOfNextMonth", TypeOf(Filter.Recorder.Value) = Type("DocumentRef.OBEntryARAP"));
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		
		Query.ExecuteBatch();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueueDuringExchange()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	TypeOfRegistrar = TypeOf(Filter.Recorder.Value);
	If OnlineARAPAccountingServer.ListOfPlanRegistrarTypes().FindByValue(TypeOfRegistrar) <> Undefined Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query("SELECT
		|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
		|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
		|	DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
		|	DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
		|	DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP,
		|	DocumentAmountsInAccountingCurrency.Period AS Period,
		|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
		|	DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
		|	DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|	DocumentAmountsInAccountingCurrency.VATBaseLocal AS VATBaseLocal,
		|	DocumentAmountsInAccountingCurrency.VATAmountCompl AS VATAmountCompl,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATMan AS AmountExcludingVATMan,
		|	DocumentAmountsInAccountingCurrency.VATAmountMan AS VATAmountMan,
		|	DocumentAmountsInAccountingCurrency.AmountGiven AS AmountGiven,
		|	DocumentAmountsInAccountingCurrency.AmountGivenCompl AS AmountGivenCompl,
		|	DocumentAmountsInAccountingCurrency.AmountGivenMan AS AmountGivenMan,
		|	DocumentAmountsInAccountingCurrency.Currency AS Currency,
		|	DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
		|	DocumentAmountsInAccountingCurrency.VATBasePeriod AS VATBasePeriod,
		|	DocumentAmountsInAccountingCurrency.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|	DocumentAmountsInAccountingCurrency.PaymentType_ AS PaymentType_
		|INTO DocumentAmountsInAccountingCurrencyBeforeWrite
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|WHERE
		|	DocumentAmountsInAccountingCurrency.Recorder = &Recorder
		|");
		
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		If AdditionalProperties.Property("TempTablesManager") Then
			Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Else
			Query.TempTablesManager = New TempTablesManager;
			AdditionalProperties.Insert("TempTablesManager", Query.TempTablesManager);
		EndIf;

		Query.Execute();
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	TypeOfRegistrar = TypeOf(Filter.Recorder.Value);
	If OnlineARAPAccountingServer.ListOfPlanRegistrarTypes().FindByValue(TypeOfRegistrar) <> Undefined Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Recorder,
		|	Table.Period AS Period
		|INTO QueueDataForAdditionalDocuments
		|FROM
		|	(SELECT
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.Recorder AS Recorder,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.RowID AS RowID,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountExcludingVAT AS AmountExcludingVAT,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATAmount AS VATAmount,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountARAP AS AmountARAP,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountVATARAP AS AmountVATARAP,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.Period AS Period,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATRate AS VATRate,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.ARAPObject AS ARAPObject,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATBaseLocal AS VATBaseLocal,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATAmountCompl AS VATAmountCompl,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountExcludingVATMan AS AmountExcludingVATMan,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATAmountMan AS VATAmountMan,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountGiven AS AmountGiven,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountGivenCompl AS AmountGivenCompl,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.AmountGivenMan AS AmountGivenMan,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.Currency AS Currency,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.ARAPCurrency AS ARAPCurrency,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.VATBasePeriod AS VATBasePeriod,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|		DocumentAmountsInAccountingCurrencyBeforeWrite.PaymentType_ AS PaymentType_
		|		
		|	FROM
		|		DocumentAmountsInAccountingCurrencyBeforeWrite AS DocumentAmountsInAccountingCurrencyBeforeWrite
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
		|		DocumentAmountsInAccountingCurrency.RowID AS RowID,
		|		-DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
		|		-DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
		|		-DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
		|		-DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP,
		|		DocumentAmountsInAccountingCurrency.Period AS Period,
		|		DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
		|		DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
		|		DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|		-DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|		-DocumentAmountsInAccountingCurrency.VATBaseLocal AS VATBaseLocal,
		|		-DocumentAmountsInAccountingCurrency.VATAmountCompl AS VATAmountCompl,
		|		-DocumentAmountsInAccountingCurrency.AmountExcludingVATMan AS AmountExcludingVATMan,
		|		-DocumentAmountsInAccountingCurrency.VATAmountMan AS VATAmountMan,
		|		-DocumentAmountsInAccountingCurrency.AmountGiven AS AmountGiven,
		|		-DocumentAmountsInAccountingCurrency.AmountGivenCompl AS AmountGivenCompl,
		|		-DocumentAmountsInAccountingCurrency.AmountGivenMan AS AmountGivenMan,
		|		DocumentAmountsInAccountingCurrency.Currency AS Currency,
		|		DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
		|		DocumentAmountsInAccountingCurrency.VATBasePeriod AS VATBasePeriod,
		|		DocumentAmountsInAccountingCurrency.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|		DocumentAmountsInAccountingCurrency.PaymentType_ AS PaymentType_
		|	FROM
		|		InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|	WHERE
		|		DocumentAmountsInAccountingCurrency.Recorder = &Recorder) AS Table
		|
		|GROUP BY
		|	Table.Recorder,
		|	Table.RowID,
		|	Table.Period,
		|	Table.VATRate,
		|	Table.ARAPObject,
		|	Table.RecalculateBasedOnARAPData,
		|	Table.Currency,
		|	Table.ARAPCurrency,
		|	Table.VATBasePeriod,
		|	Table.RecordedInARAPAccounting,
		|	Table.PaymentType_
		|
		|HAVING
		|	SUM(Table.AmountExcludingVAT) <> 0
		|	OR SUM(Table.VATAmount) <> 0
		|	OR SUM(Table.AmountExcludingVATCompl) <> 0
		|	OR SUM(Table.VATBaseLocal) <> 0
		|	OR SUM(Table.VATAmountCompl) <> 0
		|	OR SUM(Table.AmountExcludingVATMan) <> 0
		|	OR SUM(Table.VATAmountMan) <> 0
		|	OR SUM(Table.AmountARAP) <> 0
		|	OR SUM(Table.AmountVATARAP) <> 0
		|	OR SUM(Table.AmountGiven) <> 0
		|	OR SUM(Table.AmountGivenCompl) <> 0
		|	OR SUM(Table.AmountGivenMan) <> 0
		|
		|INDEX BY
		|	Recorder
		|";

		Query.ExecuteBatch();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject,
				Query.TempTablesManager);
		
		TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
			"QueueDataForAdditionalDocuments");

	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
